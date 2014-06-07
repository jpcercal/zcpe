<?php

namespace Cekurte\ZCPEBundle\Controller;

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\JsonResponse;
use Cekurte\GeneratorBundle\Controller\CekurteController;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Method;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use JMS\SecurityExtraBundle\Annotation\Secure;
use Cekurte\ZCPEBundle\Entity\Category;
use Cekurte\ZCPEBundle\Entity\Question;

/**
 * Api controller.
 *
 * @Route("/api")
 *
 * @author João Paulo Cercal <sistemas@cekurte.com>
 * @version 0.1
 */
class ApiController extends CekurteController
{
    /**
     * Lists all Category entities.
     *
     * @Route("/categories")
     * @Method("GET")
     * @Secure(roles="ROLE_API")
     *
     * @return JsonResponse
     *
     * @author João Paulo Cercal <sistemas@cekurte.com>
     * @version 0.1
     */
    public function categoriesAction()
    {
        $categoryRepository = $this->get('doctrine')->getRepository('CekurteZCPEBundle:Category');

        $categoryFilter = new Category();
        $categoryFilter->setDeleted(false);

        $result = $this
            ->getEntityRepository()
            ->getQuery($categoryFilter)
            ->getResult()
        ;

        var_dump($result);
    }
}
